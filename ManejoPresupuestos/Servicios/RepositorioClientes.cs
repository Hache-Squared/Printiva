using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioClientes
    {
        Task<IEnumerable<Cliente>> ObtenerTodos(int usuarioId, bool incluirInactivos = true);
        Task<Cliente?> ObtenerPorId(int usuarioId, int id);
        Task<int> Crear(int usuarioId, ClienteFormViewModel cliente);
        Task Actualizar(int usuarioId, ClienteFormViewModel cliente);
        Task BorrarLogico(int usuarioId, int clienteId);
        Task Reactivar(int usuarioId, int clienteId);
    }

    public class RepositorioClientes : IRepositorioClientes
    {
        private readonly string connectionString;

        public RepositorioClientes(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection")!;
        }

        public async Task<IEnumerable<Cliente>> ObtenerTodos(int usuarioId, bool incluirInactivos = true)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QueryAsync<Cliente>(
                "procObtenerClientes",
                new
                {
                    loginId = usuarioId,
                    elementoObtenerId = (int?)null,
                    SoloActivos = incluirInactivos ? 1 : 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Cliente?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);

            return await connection.QueryFirstOrDefaultAsync<Cliente>(
                "procObtenerClientes",
                new
                {
                    loginId = usuarioId,
                    elementoObtenerId = id,
                    SoloActivos = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<int> Crear(int usuarioId, ClienteFormViewModel cliente)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraClientes",
                new
                {
                    elementoAlterarId = 0,
                    nombre = cliente.Nombre,
                    apellidoPaterno = cliente.ApellidoPaterno,
                    apellidoMaterno = cliente.ApellidoMaterno,
                    telefono = cliente.Telefono,
                    instagram = cliente.Instagram,
                    whatsApp = cliente.WhatsApp,
                    email = cliente.Email,
                    direccion = cliente.Direccion,
                    esEmpresa = cliente.EsEmpresa,
                    rfc = cliente.RFC,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 0,
                    reactivar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo crear el cliente.");

            return res.ElementoId;
        }

        public async Task Actualizar(int usuarioId, ClienteFormViewModel cliente)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraClientes",
                new
                {
                    elementoAlterarId = cliente.ClienteId,
                    nombre = cliente.Nombre,
                    apellidoPaterno = cliente.ApellidoPaterno,
                    apellidoMaterno = cliente.ApellidoMaterno,
                    telefono = cliente.Telefono,
                    instagram = cliente.Instagram,
                    whatsApp = cliente.WhatsApp,
                    email = cliente.Email,
                    direccion = cliente.Direccion,
                    esEmpresa = cliente.EsEmpresa,
                    rfc = cliente.RFC,
                    loginId = usuarioId,
                    actualizar = 1,
                    borrar = 0,
                    reactivar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo actualizar el cliente.");
        }

        public async Task BorrarLogico(int usuarioId, int clienteId)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraClientes",
                new
                {
                    elementoAlterarId = clienteId,
                    nombre = (string?)null,
                    telefono = (string?)null,
                    instagram = (string?)null,
                    whatsApp = (string?)null,
                    email = (string?)null,
                    direccion = (string?)null,
                    esEmpresa = (bool?)null,
                    rfc = (string?)null,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 1,
                    reactivar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo desactivar el cliente.");
        }

        public async Task Reactivar(int usuarioId, int clienteId)
        {
            using var connection = new SqlConnection(connectionString);

            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraClientes",
                new
                {
                    elementoAlterarId = clienteId,
                    nombre = (string?)null,
                    telefono = (string?)null,
                    instagram = (string?)null,
                    whatsApp = (string?)null,
                    email = (string?)null,
                    direccion = (string?)null,
                    esEmpresa = (bool?)null,
                    rfc = (string?)null,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 0,
                    reactivar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo reactivar el cliente.");
        }
    }
}