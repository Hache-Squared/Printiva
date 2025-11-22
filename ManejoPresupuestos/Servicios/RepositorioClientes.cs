using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioClientes
    {
        Task<IEnumerable<Cliente>> ObtenerTodos(int usuarioId);
        Task Crear(Cliente cliente);
        Task<Cliente?> ObtenerPorId(int usuarioId, int id);
        Task Actualizar(int usuarioId, Cliente cliente);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioClientes : IRepositorioClientes
    {
        private readonly string connectionString;

        public RepositorioClientes(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Cliente>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Cliente>(
                "procObtenerClientes",  // Asume SP equivalente para clientes
                new
                {
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(Cliente cliente)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblClientes (Nombre, Telefono, Correo)
                    VALUES (@Nombre, @Telefono, @Correo);
                    SELECT SCOPE_IDENTITY();
                ",
                cliente
            );
            cliente.ClienteId = id;
        }

        public async Task<Cliente?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Cliente>(
                "procObtenerClientes",  // Asume SP equivalente para clientes
                new
                {
                    elementoObtenerId = id,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Actualizar(int usuarioId, Cliente cliente)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Cliente>(
                "procAlteraClientes",  // Asume SP equivalente para alterar clientes
                new
                {
                    elementoAlterarId = cliente.ClienteId,
                    nombre = cliente.Nombre,
                    telefono = cliente.Telefono,
                    correo = cliente.Correo,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Cliente>(
                "procAlteraClientes",  // Asume SP equivalente para alterar clientes
                new
                {
                    elementoAlterarId = id,
                    nombre = "Cliente eliminado",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
