using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioFilamentoTipos
    {
        Task<IEnumerable<FilamentoTipo>> ObtenerTodos();
        Task Crear(FilamentoTipo tipo);
        Task<FilamentoTipo?> ObtenerPorId(int id);
        Task Actualizar(int usuarioId, FilamentoTipo tipo);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioFilamentoTipos : IRepositorioFilamentoTipos
    {
        private readonly string connectionString;

        public RepositorioFilamentoTipos(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<FilamentoTipo>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<FilamentoTipo>(
                @"
                    SELECT * FROM TblFilamentosTipos
                "
            );
        }

        public async Task Crear(FilamentoTipo tipo)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblFilamentosTipos (Nombre)
                    VALUES (@Nombre);

                    SELECT SCOPE_IDENTITY();
                ",
                tipo
            );

            tipo.FilamentoTipoId = id;
        }

        public async Task<FilamentoTipo?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<FilamentoTipo>(
                @"
                    SELECT * FROM TblFilamentosTipos WHERE FilamentoTipoId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(int usuarioId, FilamentoTipo tipo)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<FilamentoTipo>(
                "procAlteraFilamentosTipos",
                new
                {
                    elementoAlterarId = tipo.FilamentoTipoId,
                    nombre = tipo.Nombre,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<FilamentoTipo>(
                "procAlteraFilamentosTipos",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Tipo eliminado",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
